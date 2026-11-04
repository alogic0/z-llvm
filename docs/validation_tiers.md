# Validation Tiers

Adopted 2026-07-11 (user-approved). This supersedes the earlier rule that
`distribution-all` must be green before every commit.

Policy: focused commits must pass their change-impact gate (tier 1 or 2
per the routing table). Capability-closing, ratchet-moving, ABI-affecting,
and milestone commits must pass the full integration gate (tier 3).
During sensitive multi-commit work, intermediate commits may be marked
"not yet milestone-green" in the commit body; full green is required
before moving to another capability family, closing a tracker item, or
advancing any ratchet.

## Authority And Precedence

This file is the authoritative validation policy. `docs/working-cycle.md`
applies it to worker mechanics, and roadmap/checklist documents record goals
and historical evidence. If an older roadmap entry says that
`distribution-all` must run before every commit, that wording is historical
and does not override this file.

Before starting a tier-3 run, record in the worker log or cycle notes:

- the changed subsystem;
- the tier-3 trigger from this file;
- the exact command and intended evidence output;
- why an existing result cannot be reused.

Do not rerun a gate against unchanged relevant inputs when an existing log
already proves the required result. Reuse requires the same relevant source
state, Zig pin, target, mode, corpus, pipeline arguments, and expected-result
contract.

## Tier 1 — inner loop (seconds to a few minutes)

Run after each small implementation change:

- the relevant unit-test file or test filter;
- the focused selector/lowering test for the change;
- machine verification;
- assembly + encoding tests for newly introduced instruction forms;
- one executable semantic test exercising the changed behavior;
- the currently failing real row, usually in one mode.

## Tier 2 — capability close (several minutes)

Run when a coherent capability slice is ready to commit ("support icmp ne
against zero", "consume scalar spill locations" — not every edit inside
those slices):

- unit tests;
- structural smoke;
- the codegen/object-inspection gates relevant to the change;
- the executable canary suite (below);
- a limited real-row subset: the failing row, several rows from the same
  failure cluster, and the previously closed row most similar to the new
  feature;
- ReleaseFast plus the mode most sensitive to the change.

## Tier 3 — full integration (`distribution-all`)

The authoritative serial Tier-3 command is
`zig build distribution-all -- --serial` with explicit `--zig-emitter`,
`--real-rows-validation-root`, and `--real-rows-cache-root` selections (see the
[root setup example](../README.md)). It uses the tracked 17-subgate
inventory, exclusive runner-owned paths, immutable bundle identity checks, and
durable headroom reporting. The earlier ignored
`tmp/inbox66c_serial_tier3_fresh.sh` wrapper is obsolete historical evidence;
it is not deleted, but must not be used for a new acceptance run.

Run:

- before closing a roadmap/tracker item;
- before advancing a strict ratchet (the full strict prefix runs here,
  not per inner-loop commit);
- after changes to shared ABI, frame layout, register allocation,
  relocation, AIR export, or linker boundaries;
- before claiming any evidence-backed milestone;
- periodically after a series of low-risk commits.

Tier 3 is not the default end of every worker cycle. After a tier-3 run,
inspect and record its result before starting another cycle or another full
run. A failed run is investigated with the narrowest reproducing subgate.

### Row-closure batching (amendment 2026-07-14, user-directed)

Individual compiler_rt row closures are recorded as provisional
(Tier-2/native-proven) on focused Tier 2 plus exact native row evidence.
One cumulative Tier 3 accepts the batch: at the end of a two-step
pipeline (not once per half, unless the first half must be independently
accepted before the second can safely begin), or at the
four-to-six-commit or family checkpoint for batches of low-risk
closures. Immediate Tier 3 is retained for confirmed wrong-code repairs
and for changes to ABI, shared frame layout, relocation/linker
ownership, AIR export, verifier invariants, or milestone claims. Do not
launch Tier 3 during a read-only periodic review or merely because the
worker stopped. A provisional closure is not a completed tracker claim
until the cumulative Tier 3 accepts it.

## Change-impact routing

Explicit and binding — do not decide ad hoc that a risky change is
"probably safe". Historical note: this project's selector-layer
regressions (loop-sum; call_chain) manifested in captured `.ll`
distribution rows, so selector/allocator/encoder changes always include
the captured-row object smoke, which the generic version of this table
would have missed.

| Changed area | Required gate (minimum) |
| --- | --- |
| Documentation, inventories | documentation validation only |
| IR parser/verifier | unit tests, readiness, parser corpus |
| Optimizer pass | pass fixtures, compare-opt, readiness |
| AIR model/lowering | AIR tests, focused real rows, relevant modes |
| Selector / register allocator | selector tests, executable canaries, captured-row object smoke, real-program boundary |
| Machine instructions / encoder | encoding, assembly, captured-row object inspection, executable probe |
| ABI / frame / calls | all modes, native link, executable gates (tier 3) |
| ELF / relocations | object inspection, linker boundary, full distribution (tier 3) |
| Gate/cache infrastructure | full distribution plus fresh/cache comparison (tier 3) |
| Public CLI surface: usage/help text, option parsing, the `Emit` enum, supported emit modes, or linker/CRT ownership wording | `zig build distribution-linker-boundary` before acceptance, even when the change is otherwise classified non-semantic |

Validation-impact rule (2026-07-15, from the INBOX-66 boundary stop): a change
that alters the public CLI surface above must run the focused
`distribution-linker-boundary` gate before acceptance. O0 (INBOX-64) added the
`selection-owner-manifest` emit mode to the help line and was accepted on
strengthened Tier 2 with the Tier-3 waiver, but that gate is a serial-Tier-3
subgate, so the stale boundary assertion was not caught until INBOX-66's Tier 3.
The Tier-3 waiver was reasonable for non-semantic metadata; the omission was not
running this focused boundary gate once the public CLI surface changed.

## Executable canary suite

The permanent, deterministic runtime checks; every tier-2 run executes
them. Current members: the syscall hello (three modes), the compiler_rt
i128 arithmetic program, the fma program, the setcc predicate program, the
aggregate-SSE-return program, and the mandatory `abi-differential` gate over
ten audited accepted compiler-rt functions in all three modes. The existing
seven integrated-executable cases remain seven.

The integrated-executable runner also requires Zig's unchanged upstream
`hello_libc.zig` in all three release modes through the local preopt optimizer
and object emitter. Its one-program/three-mode paired executions form a separate
population from the original seven cases and the compiler-core cohort.

It also requires the unchanged C compiler fixture from the pinned Zig tree in
three local pipeline modes. Two argument cases per mode and 66 native call/heap
observations are separate populations. The latter include 48 integer-variadic
and 18 heap-call observations. C sanitizers are disabled; full Zig startup is
still an explicit boundary. The frozen compiler-core population remains 100
rows, with five cohort functions and 256 ASCII inputs per mode.

The same runner also requires the
[pointer/length memory canary](evidence/startup_word_pair_memory_20261102.json).
Two functions use direct and release routes in all three modes, producing 384
local observations against 192 LLVM-reference observations reused across routes.
Independent expected fields and guards check copy independence, pointer and length
preservation, and composed ownership. This standalone population does not change
the original seven integrated cases, the C fixture's six paired cases/66 call
observations, or compiler-core and compiler-rt counters.

The mandatory [scalar frame-store canaries](evidence/scalar_frame_acceptance_20261103.json)
add four pointer functions (768 local/384 reference observations) and three scalar
functions (486 local/243 reference observations). Each uses direct and release
routes in all three modes; references are reused across routes. They check runtime
and returned pointers, caller-clobbering calls, full-width constants through frame
and ordinary-pointer destinations, literal null, live values and guards. These
populations are separate from all existing counters and canaries above.

The mandatory [scalar startup canaries](evidence/scalar_startup_acceptance_20261103.json)
add four integer-to-pointer functions and four signed nonnegative-compare
functions. Each population has 1,536 local observations against 768 LLVM
references reused across direct/release routes in three modes. They check exact
bits/booleans, signed extrema, register/spill/returned inputs, caller clobbers,
live values and output guards. These standalone observations leave all earlier
population counters unchanged.

The mandatory [allocation-padding canary](evidence/allocation_padding_acceptance_20261103.json)
adds four scalar/nested/array GEP functions. Direct/release routes in three modes
produce 768 local observations against 384 LLVM references reused across routes.
It checks allocation padding for `i24` and `x86_fp80`, including nested layouts;
all existing populations remain separate.

The mandatory [global-memory canaries](evidence/global_memory_acceptance_20261103.json)
add four address functions (192 local/96 reference observations) and seven
copy/store functions (240 local/120 reference observations). Direct/release
routes run in all three modes, reusing references across routes. They check
defined global bytes, pointer fixups, alignment, local symbols, full integer
bits, guarded 2/12/16/80-byte copies, narrow stores and live-value preservation.
These standalone populations leave all previous counts unchanged.

The mandatory [boolean-call canary](evidence/boolean_call_acceptance_20261103.json)
adds four scalar/branch/frame-pointer/live-return functions. Direct/release routes
in all three modes produce 1,536 local observations against 768 LLVM references
reused across routes. The callees dirty upper RAX bits and clobber volatile integer
registers; the branch consumes the result before any extending cast. Three
recorded controls reject removal of call-result normalization. Existing population
counts remain separate and unchanged.

The mandatory [array-stride canary](evidence/array_stride_acceptance_20261103.json)
adds four functions with eight-byte, padded i24, nested-array and frame-reloaded
pointer/index cases. Direct/release routes in three modes check 1,536 local
observations against 768 LLVM references reused across routes. Negative indexes,
wrapping addresses, live operands and guarded stores are checked. Six recorded
controls reject a wrong scale or stale store-value ordering. Its standalone
population does not change compiler-core execution counts.

The accepted [module dependency canary](evidence/module_selection_acceptance_20261103.json)
uses explicit reachable selection through direct/release routes in three modes.
Seven selected functions pass 330 local observations against 165 LLVM references
reused across routes. It checks helper chains, recursion, callback globals,
function/data aliases, imports, local bindings and hidden visibility. Thirty
controls require rejection before object publication, and three checks require
identical CLI/environment-selected objects. All 17 integration stages pass on the
frozen source snapshot; the default selection, compiler-core counts and bypass
ratchet remain unchanged.

The accepted [IR serialization and headroom checkpoint](evidence/ir_headroom_acceptance_20261103.json)
adds optimizer-correctness regressions for numeric locals, quoted parameter names,
generated-name collisions and function-bound block addresses. Ten functions over
16 inputs and three optimizer pipelines produce 480 observations of locally
optimized IR executed by Clang-22 against 160 reused LLVM references. These
checks add no local machine-code execution credit. All 1,718 units, readiness
and 13 structural checks pass. The accompanying policy schema 3 passes its
17-stage fresh/cached pair with 1,406 matching canonical records and unchanged
candidate, execution and bypass counts. The 32.95 GB admission and 24.36 GB
runtime floor are enforced with the existing 8 GiB forecast.

The accepted [symbol identity checkpoint](evidence/symbol_identity_acceptance_20261103.json)
adds permanent optimizer-correctness checks for escaped stores, pointer and alias
escapes, reverse quoted definitions, and distinct numbered/quoted numeric globals.
Five entry points over 16 inputs and three pipelines produce 240 observations
of locally optimized IR executed by Clang against 80 reused references. All
1,727 units, 13 structural tests, readiness and the 17-stage cached integration
run pass. Current exports are authenticated again and execution is rerun;
this repair adds no local machine-code or whole-program execution credit.

Inside the i128 and fma cases, the mandatory runner uses the same production
canary implementation as the standalone focused tool to require the frozen
__multi3 and fma machine
streams, exact symbol bytes, fma ldexp/add_and_denorm helper identities, and
executable proofs. FMA additionally requires 8,192 seeded, bitwise comparisons
with LLVM compiling the identical frozen IR. A mandatory mismatch negative invokes that fixed-hash
production validator on every runner execution; accepted identities have no
runtime override. The ABI gate's paired-execution counters belong only to the
285-function compiler-rt population and do not describe the separate 100-row
compiler-core distribution population. Every
executable semantic case added under the INBOX-10 rule (each new
arithmetic/comparison/branch/call/spill capability lands with one) joins
this suite. Canaries are never removed, only extended; determinism is
required — no random sampling.

## Frontier, not prefix, during development

Inner-loop cycles validate the failing frontier row and nearby cluster
rows, not the whole strict prefix. The full strict prefix in all modes
runs at tier 3 when a ratchet moves or an item closes.

## Measurement before optimization

Gate-runner infrastructure work (subgate timing report first, then
tool/artifact reuse, mode parallelism, stage caching, build-graph
restructuring) proceeds in the order the measured numbers justify —
the timing report is the prerequisite for all the others. Implementation order,
acceptance criteria, and supervisor continuation rules are defined in
[`roadmap/distribution_all_optimization_plan.md`](roadmap/distribution_all_optimization_plan.md).

For gate/cache infrastructure measurement, the required comparison is exactly:

1. one fresh run for the current implementation state;
2. one cached run against that same state;
3. a comparison of summary lines, cache status, and subgate timings.

Do not repeat either full run unless the gate/cache implementation or another
relevant input changes after the measurement.

### Behavioral canaries (2026-09-10)

`zig build behavioral-diff` runs the additional standalone IR program population
against LLVM 22. The integrated-executable subgate invokes the same implementation.
Its case/mode, distinct-function, and input-observation counts are separate from
both the fixed compiler-core cohort and the original seven integrated cases.
Focused reproduction uses `zig build behavioral-diff -- --case CASE_ID`.

### Retained memset family canary

`zig build memset-diff` executes three retained real-function definitions and six
compositions through direct and release-o3 routes in three harness modes. It
checks bytes, returned pointers, preservation of live values, and bounds traps;
every function must have composed ownership. The integrated-executable subgate
runs the same implementation. Its counts remain separate from accepted corpus
counters; see [the family evidence](evidence/composed_memset_family.md).

### Retained memcpy family canary

`zig build memcpy-diff` executes two retained definitions and seven compositions
through direct and release-o3 routes in three harness modes. It checks bytes,
source preservation, returned pointers, live scalar/vector values and bounds
traps. The integrated-executable subgate runs the same implementation. Counts
remain separate from accepted corpus counters; see [the family evidence](evidence/composed_memcpy_family.md).

### Scalar byte-loop canary

`zig build byte-loops-diff` executes retained checked strncpy, bcmp and memcmp
plus four scalar byte-loop compositions through direct/release-o3 routes in
three harness modes. It requires composed ownership and checks bytes, scalar
results, protected-page boundaries and paired bounds traps. The integrated
executable gate invokes the same implementation; its population is separate
from accepted corpus counters. See [the evidence](evidence/composed_byte_loops.md).
