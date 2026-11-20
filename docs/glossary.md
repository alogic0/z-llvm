# Glossary

Explanations and concrete examples for the terms used in the convergence
work (`docs/roadmap/end_to_end_convergence_plan.md`,
`docs/roadmap/convergence_progress.md`) and in progress reports. Examples
are real ones from this repository's history.

## 1. Compilation pipeline representations

**Zig source** — the `.zig` files being compiled. Example: the real corpus
is `../ziglang/src/main.zig` and everything it imports — the Zig compiler
itself.

**AST (abstract syntax tree)** — the parsed form of one source file; pure
syntax, no meaning yet. Produced by the tokenizer and parser inside
`../ziglang`.

**ZIR (Zig Intermediate Representation)** — an untyped, per-file
instruction stream generated from the AST before any semantic analysis.
Generic functions and `comptime` code are still unexpanded at this level.

**Sema** — Zig's semantic analysis stage. It interprets ZIR, executes
`comptime` code, resolves all types, and instantiates generics. Its output
is AIR.

**Comptime** — Zig code executed during compilation by Sema. By the time
AIR exists, comptime code has already run; only its results remain.

**Monomorphization / generic instantiation** — creating one concrete copy
of a generic function per distinct set of comptime arguments. This is why
the compiler-core inventory counts 61,386 functions, about 38,000 of them
generic instantiations — e.g. dozens of separate `hash_map.*.Metadata.*`
functions that are all the same source code instantiated with different
types.

**AIR (Analyzed Instruction Representation)** — Zig's typed, per-function
IR after Sema: fully resolved types, explicit safety checks, one body per
instantiation. This is the representation z_llvm consumes. Unlike LLVM IR,
AIR control flow is *structured*: `block` and `loop` instructions contain
nested bodies and `repeat` jumps back to the loop head — there is no flat
basic-block graph with phis. Example instruction from a gate log:
`typed_inst|1|ret|8|noreturn|un_op|1|const|3|126|4|bool|1|...`.

**AIR descriptor / typed-v2 facts** — the serialized export format the
patched stage4 Zig writes for z_llvm: the AIR instruction stream plus
extra "fact" records emitted under named hook contracts (for example
`zllvm-union-tag-facts-v1` carries a union's tag index and bit width;
`nav_fqn` records carry fully-qualified symbol names). This format is the
contract between the two repositories. A full compiler-core descriptor is
about 1.4 GB per release mode.

**Hook contract** — a named, versioned agreement about one fact record the
Zig-side exporter emits and z_llvm consumes (e.g. `zllvm-splat-v1`,
`zllvm-aggregate-layout-facts-v1`). Versioning keeps the boundary explicit
so neither side silently depends on the other's internals.

**z_llvm IR** — this project's own LLVM-IR-workalike, implemented in Zig:
functions, basic blocks, SSA-style values, operations like `insertvalue`,
`shufflevector`, `llvm.sadd.with.overflow.i32`, plus a verifier. It has a
textual form compatible enough with LLVM IR that captured `.ll` files
parse into it and LLVM's own `opt-22` can be used as a comparison oracle.
The optimizer passes (the project's first finished milestone) run here.

**MachineFunction** — z_llvm's machine-level representation of one
function: a list of concrete x86_64 instructions such as `sub_rsp_24`,
`spill_arg_rsp`, `direct_call`, `ret`, produced by the x86_64 codegen
layer from z_llvm IR. Register and stack-frame decisions are made here.

**Mir (upstream Zig)** — the analogous machine layer inside `../ziglang`'s
own self-hosted backend (`src/codegen/x86_64/Mir.zig`). Deliberately kept
1:1 with machine instructions; its documented purpose is only to postpone
offset assignment so short jump encodings can be chosen. Not used by
z_llvm, but its encoder and `encodings.zon` instruction tables are a reuse
candidate (tracker item 15 note).

**Legalize / Liveness (upstream Zig)** — upstream's AIR-level pass
infrastructure: `src/Air/Legalize.zig` rewrites AIR forms a backend cannot
handle into forms it can; `src/Air/Liveness.zig` computes value lifetimes
on AIR for the backends' register assignment. Together they show where
upstream intends optimization to live: on AIR, not on Mir.

**ELF object** — the compiled output of one gate row or program before
linking: x86_64 machine code bytes in sections, with symbols and
relocations. Emitted by `mc/encoding.zig` + `mc/assembly.zig`. Example
artifacts: `tiny_scalar.o` with its `readelf` dump in the gate temp dirs.

**Relocation** — a placeholder in an object file that the linker patches
with a final address, e.g. the target of a `direct_call` to another
function.

**Native linker (no LLD)** — Zig's own linker, used to combine z_llvm's
ELF objects into executables. LLD is LLVM's linker; the goal requires
`lld_rows=0`, meaning it is never used.

**LLVM TargetMachine** — the LLVM component that turns LLVM IR into
machine code. The goal requires `llvm_targetmachine_rows=0`: no function
may reach an executable through it.

## 2. Project architecture terms

**Model-owned facts / typed lowering** — the rule that z_llvm may accept a
construct only when typed AIR facts prove its shape (via a model such as
`TypedUnionTagGetSummary`), never by recognizing names or scraping AIR
text. Example: `get_union_tag` is lowered from the exported `bit_width`
fact, not from seeing a function called "getTag".

**Source-name admission (forbidden)** — the anti-pattern the rule above
bans: accepting a row because its source file or function name matches a
list. Historically caused silent regressions (see
`loop-sum` in project notes); every fix commit states it was not used.

**Fail-closed** — when z_llvm meets a form it cannot prove, it must stop
with a diagnostic rather than guess. Example: exported vector ABI fails
with `UnsupportedVectorAbi` instead of emitting possibly-wrong code.

**Boundary** — a deliberately unsupported form, held fail-closed and
covered by a boundary gate that checks the *right* diagnostic fires.
Example: `@tagName` is a `tag-name` boundary with
`UnsupportedTagNameBoundary` until string ownership exists.

**Shape recognizer** — a backend routine that matches a whole known
data-flow pattern in a function and emits code for exactly that pattern
(e.g. "single stack slot + one call + return"). Fast to add, fragile at
scale: adding one for the first real row regressed a captured row through
recognizer-chain ordering (the `call_chain` incident). Tracker item 15
replaces them with per-instruction selection.

**Recognizer escalation / three-strikes** — the tripwire on that
fragility: every fix commit reports whether it added a recognizer reorder,
ordering constraint, or whole-function pre-pass. The count stands at 1
(the `call_chain` fix). At 3, work stops for an architectural review that
should pull item 15 forward.

**Instruction selection / register allocation / spill** — the classical
backend jobs item 15 introduces incrementally: choosing machine
instructions per IR instruction, assigning values to registers, and
storing values to stack slots when registers run out.

**SysV ABI** — the x86_64 Linux calling convention: which registers carry
arguments and results, how aggregates are classified (INTEGER/SSE/MEMORY),
when a hidden `sret` pointer is used for large returns. The frontier
proved these with rows like `frontier_mixed_make` (a `{ i64, double }`
returned in RAX + XMM0).

**sret** — "structure return": returning a large aggregate by writing it
through a hidden pointer argument instead of registers. Example row:
`frontier_big20_copy`.

**Stage4** — the locally built patched Zig compiler binary containing the
AIR exporter hooks. It must match the tracked ziglang pin; the
`check-zig-stage4-emitter` gate verifies that.

**Ziglang pin** — `docs/evidence/ziglang_pin.txt`: the exact `../ziglang`
commit the stage4 binary was built from. Everything (cache keys, evidence
summaries, ratchet denominators) cites it, so results are reproducible
even when `../ziglang` HEAD moves on.

**Export cache** — the item-8a infrastructure: exported AIR descriptors
cached under `tmp/`, keyed on (pin, exporter-relevant z_llvm state, mode,
slice) and reused across gate runs. Cut per-mode gate startup from ~9
minutes to ~15 seconds. Fail-closed: any key mismatch re-exports.

## 3. Process and workflow terms

**Convergence plan** — `docs/roadmap/end_to_end_convergence_plan.md`: the
frozen strategy document defining the goal (real programs and eventual
self-host through z_llvm, no TargetMachine, no LLD), the phases, and the
metric rules.

**Tracker / progress checklist** —
`docs/roadmap/convergence_progress.md`: the durable record of numbered items,
ratchets, report topology, and historical progress. It proposes and ranks work
but does not authorize execution.

**Worker** — the coding agent (a Codex CLI session) that performs the action
authorized by the current worker-inbox directive or `docs/next_steps.md`, then
implements, validates as directed, and commits. Distinct from the
docs/verification agent (Claude), which maintains the docs and audits the
worker's commits but does not write project code.

**Working cycle** — one unit of worker work as defined in
`docs/working-cycle.md`: one goal, focused validation, evidence saved,
docs updated, one commit, clean tree.

**Goal selection** — first obey the controlling Active worker-inbox directive
or the authoritative current-action entry in `docs/next_steps.md`. Failing rows,
program gates, and unchecked tracker items rank choices only when that
directive explicitly delegates a bounded choice.

**Stop state / stop report** — the record a stopping worker leaves in
`docs/next_steps.md`: active item, first failing row and stage, current
counters, evidence paths, recommended next action. Lets any session resume
without lost context.

**Gate** — a build step that runs a corpus through the pipeline and fails
closed on any unexpected result, e.g. `zig build distribution-real-rows`,
`zig build distribution-all`. Gates print `summary ...` lines that become
evidence.

**distribution-all** — the umbrella gate running every distribution gate,
boundary gate, and the strict real-rows gate. Must be green before every
commit; it is what catches captured-row regressions (it caught the
`call_chain` one).

**Report mode vs strict mode** — two modes of `distribution-real-rows`.
Report mode records failures in the summary line and exits 0 (used for
discovery); strict mode (`--strict`) exits nonzero on any failure (used
for enforcement inside `distribution-all`). Example: item 6 wired report
mode first so `distribution-all` stayed green while the first row was
still being fixed.

**Fixture / frontier row** — a small hand-written Zig file under
`test/zig/frontier/` that proves one capability in isolation, checked by a
C harness. Example: `frontier_union_tag_match`. Since the pivot these are
debugging aids; progress is measured on real rows.

**Real row** — an actual function from the real compiler-core module,
selected from the candidate file and run through the gate. Example: rank 1
`math.raiseInvalid` from `../ziglang/src/main.zig`, the first real
function z_llvm ever compiled.

**Captured `.ll` row / golden file** — a saved LLVM-IR input
(`test/distribution/.../*.ll`) or expected output
(`test/codegen/expected/asm/*.s`) that pins down previously-proven
behavior. May only change when the new behavior is verified executably —
e.g. `call_stack_slot.s` changed `sub $8` to `sub $24` only because the
executable checks still passed.

**C harness** — a C `main()` that calls exported rows through the C ABI
and checks results, proving executables actually run correctly. Example:
`frontier_frontier_union_tags.c` checks both arms of a union-tag switch.

**Syscall-hello (milestone 2a)** — the first real-program milestone: a
no-`std` program exporting `_start`, printing via direct Linux `write`
syscall and exiting via `exit`, built by patched Zig with z_llvm codegen
and the native linker. Deliberately minimal so it isolates startup,
inline-asm `syscall`, and program-scale linking.

**Self-host (Phase 5)** — the end state: the Zig compiler itself built
through z_llvm, passing the behavior test suite, and able to rebuild
itself (fixed point).

**Release modes** — Zig's build modes: Debug, ReleaseFast (speed),
ReleaseSafe (speed + runtime safety checks), ReleaseSmall (size). Gates
run all three release modes; ReleaseSafe is the hardest because safety
checks add hundreds of thousands of extra instructions.

## 4. Metrics, candidates, and evidence terms

**Candidate selector / candidate file** — the inventory-driven tool that
ranks every real compiler-core function and emits
`docs/evidence/real_candidates_releasefast_v*.tsv` with one row per
function. The gate takes its top N rows. v1 shipped conservative marks;
v2 refined the facts (denominator migration).

**Candidate fields** — per-row facts: `signature_class` (C-ABI-stable /
internal-callable / not-callable), `call_class` (leaf / internal /
external), `global_refs`, `runtime_refs`, `determinism`,
`harnessable_reason`. Example row: rank 1, `math.raiseInvalid`, 1
instruction, internal-callable, leaf, no refs, `assumed_nondeterministic`.

**`assumed_nondeterministic`** — the conservative default determinism
mark: a row is not *executed* (only lowered/emitted/linked) until a
selector version proves it pure. This is why `real_executed` is still 0 —
correct behavior, not a failure.

**Staged counters (`real_*`)** — the compiler-core distribution-row counters
under schema `distribution-real-rows-v2`:
`real_functions_lowered` (typed lowering + CFG succeeded),
`real_objects_emitted` (ELF object written), `real_native_linked` (native
linker succeeded), `real_executed` (paired behavioral verification; candidate-
only zero exit does not qualify), and `real_programs_ok` (whole programs built
and run). Current strict values are 100/100/100/0/0. These counters describe
the separate 100-row compiler-core population, never the compiler-rt ABI
cohort.

**ABI differential counters (`abi_diff_*`)** — the compiler-rt-only paired-
execution counters under schema `abi-diff-v2`. `abi_diff_cases_attempted`
increments immediately before one reference/candidate input pair,
`abi_diff_cases_matched` increments only after return bits, declared memory
effects, ABI state, and termination agree, and
`abi_diff_real_functions_matched` increments once per mode after every case
for one audited real compiler-rt function matches. They are intentionally not
copied into the compiler-core `real_*` summary.

**Ratchet** — a counter that may only rise; a drop fails the gate.
Prevents silent regression of proven coverage.

**Denominator** — what a counter is measured against: the candidate-file
hash, selector version, pin, mode, and limit. Recorded with every counter
value so honest selector improvements can be told apart from regressions.

**Ratchet-migration note** — the only legal way for a counter to change
because its denominator changed: an explicit note in the evidence summary
recording old and new hashes and why. Example: the selector v1→v2
migration note in `docs/evidence/real_rows_strict_limit25_v2.md`.

**`unsupported_functions`** — the inventory's count of real compiler-core
functions not yet claimable (55,479 in ReleaseFast at the current
baseline). The long-term number Phase 4 drives below 1,000.

**Evidence summary** — a tracked report under `docs/evidence/`. Closing a
checklist item requires a reference to its report. The gate log summarizer
(`tools/summarize_gate_log.zig`) writes Markdown (`.md`) with the command,
z_llvm commit, Zig pin, exit status, summary
lines, first failure and ratchet metadata. Raw gate extracts use `.summary`.
Some frozen records cite a Markdown report by its original `.summary` name.
Use the same basename with `.md` to read it, or use the recorded revision
and original path to reproduce a historical checksum.

**Discovered State vs Ratchet State** — two tracker tables: Discovered
State holds report-mode green counts per mode (real progress, not yet
enforced — e.g. ReleaseFast 186/184/184 at limit 200); Ratchet State holds
only strict-enforced values (25/25/25). Report-mode progress never appears
in Ratchet State.

**Cluster / Cluster Board** — the item-9a method: group failing rows by
failure stage + diagnostic, fix the largest cluster with one
generalization, record how many rows it unlocked. Example: the
nominal-enum-bool-return fix unlocked ranks 66–182 (the `hash_map`
Metadata instantiations) in one commit.

**Rows unlocked** — the Cluster Board column recording each fix's payoff:
how many previously-failing rows turned green when the generalization
landed.

**Progress Log** — the append-only one-line-per-cycle achievement history
at the bottom of the tracker; the fastest way to read "what has been
achieved so far."

## 5. Testing and verification terms

**Differential testing / oracle** — validating z_llvm by comparing against
an independent implementation. Current oracle: LLVM's `opt-22` normalizing
the same textual IR. Planned (item 16): an ABI-level oracle — the same
real function compiled by stock LLVM-backed Zig and by z_llvm, both run on
generated inputs, outputs and exit codes compared.

**Executable proof** — a row is only fully trusted when a produced binary
runs and its results are checked (via the C harness or, later, the
differential harness). Weaker levels — object emitted, linked — are
tracked separately by the staged counters.

**Boundary gate** — a gate over deliberately-unsupported sources proving
each fails closed with the *correct* diagnostic
(`wrong_diagnostic_rows=0`), so unsupported forms can't silently start
being accepted.

**Strict finish counts** — fixture-gate expectations pinning exact
function counts (e.g. `.functions = 755`), so a fixture corpus can't grow
or shrink unnoticed.

**Inventory** — the body-aware scan of the real compiler module
(`zig build distribution-zig-air-inventory --slice=compiler-core-module`)
counting every function, instruction, opcode, and unsupported category.
The measurement layer everything else prioritizes from.
