# Upstream behavior and resource follow-up

The current [scalar-liveness checkpoint](compiler_behavior_scalar_liveness_checkpoint_20261112.json)
repairs the unsigned remainder error at `9cb21139`. Both 2,204-unit builds,
all 17 integration gates, both 122-population native suites, strict preservation
comparisons and all 1,162 required fault controls pass. Fresh original production
retains all 8,928 compiler and 455 runtime definitions, owners, balanced events
and valid ELF objects. The compiler object is unchanged; the expanded runtime
oracle checks 641 unsigned division/remainder cases and the formerly wrong input.
A separate test-only bridge records the corrected historical stream expectation
without changing the automatic object-reuse policy. The final generations and
complete four-mode local-hook matrices remain open. Earlier entries below retain
their checkpoint scopes and failures.

The follow-up milestones in the [compiler plan](../plans/2026-11-11-complete-compiler-object-and-self-rebuild.md)
remain open. The [PHI checkpoint](compiler_behavior_phi_checkpoint_20261111.json)
accepts the narrow repair at `84f1ad7c`; it does not establish a repaired compiler
rebuild or completion of the upstream behavior matrix.

The pinned reference passes all 2,097 named tests in Debug, ReleaseSafe,
ReleaseFast and ReleaseSmall, including each mode's recorded upstream skips.
Both previously accepted compiler generations compile the full suite through
their normal LLVM route, then fail `@exp with vectors` in all four modes.
The retained failing invocations remain failures.

The reduced case identifies a floating PHI edge that snapshots named inputs
into XMM0 before materializing a literal through that same register. Reserving
XMM0 during snapshot planning preserves the input. Executable f32/f64 tests,
the new `phi_fp_literals` native population and an independently linked runtime
exp oracle cover the repair. The original runtime again selects all 455
definitions; its owners are unchanged, and both backend build modes emit the
same complete object. The old backend fails the new regression.

Debug and ReleaseSafe each pass 2,183 unit, 63 structural and two profile checks.
Readiness and all 17 serial integration gates pass. Both complete native suites
pass all 116 populations, preserve all 4,241 prior command outcomes, and retain
identical optimizer outputs, owner manifests and objects for the preceding 115
populations. All 822 cumulative fault controls are detected. Frozen source,
backend binaries, runtime events and object checks bind these results to the
checkpoint. Historical artifact seals and provider/contract pins verify without
rewriting their manifests.

Explicit local-hook behavior attempts expose further global syntax, wide integer,
x87 vector, floating atomic, varargs and ReleaseSmall runtime boundaries. A
normal-resource frontend probe still terminates with SIGSEGV under the inherited
46 MiB main-stack limit and CPU affinity 0–15. Parent-launched debugger evidence
identifies `Sema.analyzeBodyInner`'s page-touching prologue at the failure, below
the main-stack mapping. Frame-allocation experiments remain
isolated: selecting the large Sema function does not outweigh failing existing
tests. None of that prototype is accepted into the maintained backend.

Evidence is retained under
`local-state/validations/compiler-behavior-completion-20261111/batch-01/`.
The next implementation work closes the observed local-hook boundaries and
reduces frame growth with executable regression coverage, followed by fresh
compiler generations, the full behavior matrices and normal-resource self-rebuild.

The [vector checkpoint](compiler_behavior_vector_checkpoint_20261111.json)
accepts code `a328d225`: quoted global pointer initializers, floating vector
global data and packed x87 vector lanes. Execution covers 1, 3, 16 and 64 lanes,
payloads, PHIs, comparison masks, aggregate layout and neighboring memory. All
5,686 global records from the unchanged Debug capture parse. A fresh unchanged
local-hook attempt retains a complete 455-definition runtime object and reaches
variadic function parsing in the 7,874-definition behavior module. That attempt
remains failed; the full behavior matrix is still open.

Both unit builds pass 2,188 units, 64 structural and two profile checks. Eight
readiness procedures, all 17 integration gates and both 117-population native
suites pass. Each native build preserves all 4,277 prior outcomes and all 357
optimizer, 699 owner and 705 object artifacts exactly. All 876 cumulative fault
controls are detected. Both fixed runtime objects and owners match the PHI
checkpoint, with independently balanced 455-function events and ELF audit.
The fixed bundle identity, contracts, providers and historical seals remain.

The new registry entry was moved to the tail after the frozen run to retain the
previous prefix. All fixture contracts and compiler sources are identical; fresh
strict registry and artifact comparisons pass in both builds. These independent
population executions are reused for that ordering correction. The original
frozen source has 3,420 authenticated copies under the successor evidence root,
so later source edits do not invalidate its record. No performance claim is made.

A separate frame-compaction prototype passes all 2,188 existing units, two new
stack/rebasing controls, all 117 native populations and 432 fault controls. It
reduces the measured Sema frame from 1,376,424 to 650,536 bytes while preserving
spill homes and lifetimes. Nine cross-build literal-encoding differences match
the maintained ReleaseFast backend exactly; six vector objects contain the
reviewed frame reduction. Adoption and cumulative validation remain separate
from this diagnostic result. A fresh normal-resource rebuild is still required.

The reviewed compaction code is now adopted for cumulative validation. A new
native regression runs the 64-lane operation on a fixed 64 KiB pthread stack:
the preceding backend terminates with SIGSEGV, while the prototype and LLVM
reference pass. Its three numbered faults cover the result and both surrounding
guards. This resource regression supplements the stack-argument/rebasing unit
controls; it does not establish the compiler's normal-resource rebuild.

The [frame checkpoint](compiler_behavior_frame_checkpoint_20261111.json) accepts
the trailing-gap compaction at `46c07b2d`. Both unit builds pass 2,190 units,
64 structural and two profile checks. Eight readiness procedures, all 17
integration gates and both 118-population native suites pass; all 930 required
fault controls are detected. The strict native comparisons remain failed for
six reviewed vector objects per build: each matches the independently executed
prototype exactly. All 4,313 preceding outcomes, 360 optimizer artifacts,
705 owner artifacts and the other 705 objects match. Both fixed runtime objects
are complete, with unchanged owners; the two changed complex-arithmetic bodies
also pass 24,650 independent observations per route and nine supplemental faults.

Fresh production again emits the complete original compiler object with all
8,928 definitions, unchanged owners, balanced events and a passing ELF audit.
The unchanged compiler builds and starts. Its normal LLVM route now matches all
2,097 reference test identities and outcomes in each of the four modes, and its
f80 regression passes all nine observations. These results cover the new first
generation. Normal-resource self-rebuild still fails with frontend SIGSEGV;
a new debugger trace again identifies the Sema stack-probing prologue. No second
generation or complete local-hook behavior matrix is accepted. The frozen
3,425-file source has verified retained copies before this publication.

Isolated follow-up work covers floating atomics, SysV variadic values, simple
owned module-assembly aliases and live scalar-FP frame preservation. Its complete
Debug behavior input parses and verifies, and four new native populations pass
all three modes and their faults. Production still selects only 6,554 of 7,874
definitions, so these results remain research. Further extended-return ABI work
selects the eight targeted Small-runtime functions; complete object and native
ABI proofs remain necessary before adoption. Removing unreferenced interior
spill-reserve chunks is also isolated pending semantic and resource proofs.

The next resource slice adopts explicit stack-object lifetime reuse and removes
unreferenced interior spill-reserve chunks for immediate Tier 3. It keeps every
referenced spill home separate, colors only bounded whole objects with explicit
start/end markers, and checks may-live states through branches and loops. Unknown
markers and unsupported layouts retain the original function. The isolated
candidate passes all 2,194 units and a new two-function native population in
all three modes with 27 faults. Its complete 8 KiB objects execute on a fixed
64 KiB pthread stack; the preceding backend fails there with actual SIGSEGV.
The measured Sema frame is 479,000 bytes. These proofs authorize cumulative
validation, not normal-resource self-rebuild acceptance. Compiler/runtime
replays and both final generations remain required.

The [lifetime checkpoint](compiler_behavior_lifetimes_checkpoint_20261112.json)
accepts `8b38e8cd` after fresh cumulative validation: both 2,194-unit builds,
64 structural/two profile checks each, eight readiness procedures, all 17 gates,
both 119-population native suites and all 984 required fault controls pass.
The strict native comparisons pass with all 4,349 preceding command outcomes,
363 optimizer artifacts, 711 owner artifacts and 717 objects unchanged per
build. Both complete runtime objects retain all 455 owners; the two changed
complex bodies pass the independent oracle and supplemental faults. The fresh
original compiler object contains all 8,928 definitions with unchanged owners,
balanced events and a passing ELF audit. Its frozen 3,430-file source is retained
verbatim before this publication. Timing under concurrent load makes no
performance claim.

The resulting first generation builds and starts, passes the original controls
and f80 regression, and matches all 2,097 reference outcomes in each of the four
normal LLVM modes. Its normal-resource self-rebuild still fails with SIGSEGV.
The latest debugger trace identifies `InternPool.Key.hash64`'s probing prologue
at the bottom of the inherited 46 MiB stack. The Sema frame reduction therefore
does not close the cumulative stack problem. A retained stack snapshot supports
the call-chain diagnosis: 207 owned frames and 206 checked call edges, including
95 Sema frames occupying 45,505,000 bytes. No final second generation or complete
local-hook behavior matrix is accepted.

Separately preserved research reaches 7,196/7,874 selections on the unchanged
Debug behavior input. Exact Valgrind magic, extended sret payloads, byte/halfword
XMM ABI values and constant comparisons have independent native proofs. The
comparison slice passes all 2,202 units after replacing its newly supported
constant-pair rejection input with an unsupported poison operand. Wide-integer
limb lowering remains experimental. None of these research slices is accepted
into the maintained backend by this checkpoint.

The following resource slice adopts machine-memory spill-home reuse for
immediate Tier 3. Six focused controls cover executable rebasing, loop liveness,
overlapping widths, partial writes, outgoing bias, batch boundaries and closed
escapes. All 2,201 isolated units pass. An independent placement check and the
machine verifier accept a 53,144-byte Sema frame; its batched liveness table uses
8,115,712 bytes. These are diagnostic proofs, not a successful compiler rebuild.

The new `stack_spill_homes` population passes both backend builds in all three
modes, including 45,096 independent observations per execution and all 27
fault controls per build. LLVM passes its 64 KiB worker-stack oracle; the
preceding backend fails there with actual SIGSEGV. The 512-wave Zig-generated
fixture stays within the default input limit. The earlier oversized fixture
failed setup and receives no selection or execution credit. The initial
placement also failed an existing gap-compaction unit by producing a larger
frame; the corrected choice keeps the smaller existing result, and the original
expectation passes unchanged. Cumulative validation and new original-input
compiler/runtime production remain required after adoption.

The [machine-home checkpoint](compiler_behavior_machine_homes_checkpoint_20261112.json)
accepts `ee87c488` after fresh cumulative validation: both 2,200-unit builds,
64 structural/two profile checks each, eight readiness procedures, all 17 gates,
both 120-population native suites and all 1,038 required faults pass. Both strict
comparisons retain all 4,385 prior outcomes. Their 18 changed objects per build
remain recorded as failures, with independent reviews identifying only smaller
frames in three functions; every other function symbol in those objects matches.
Complete original compiler/runtime objects retain their owners and pass ELF and
balanced-event audits. Additional complex and real/quad math oracles cover all
seven changed runtime bodies, with 18 supplemental faults. The frozen 3,436-file
source is retained verbatim. No controlled performance claim is made.

The resulting first generation builds, starts, passes the original controls and
f80 regression, and matches all 2,097 reference outcomes in each normal LLVM
mode. Actual normal-resource self-rebuild still fails with worker SIGSEGV in
`InternPool.zigTypeTag`'s probing prologue. The unchanged worker stack is 60 MiB.
A checked reconstruction records 1,213 owned frames, 1,210 direct call edges and
two indirect edges: 480 `genBodyDebugScope` frames and 481 `genBody` frames occupy
59,288,024 bytes, before other active frames. A frontend-only probe passes but
changes code-generation demand. Keep that result separate from the failed full
build, and retain the historical CPU-0/1 GiB acceptance. The next isolated repair
will measure medium-frame compaction and prove a recursive worker-stack case;
milestones 6–8 and both final local-hook matrices remain open.

The medium-frame candidate reuses the existing unused-gap proof: analyze frames
from 32 KiB and require 8 KiB of gap savings. No new liveness or alias rule is
introduced. A targeted checked export reduces `genBodyDebugScope` to 24,456
bytes. All 2,202 isolated units pass, including two new executable/closed-case
controls. The new `medium_stack_frames` native population passes both backend
builds in all three modes with 64 observations per execution and 27 faults per
build. Its four recursive kernel activations fit a fixed 128 KiB worker stack;
the preceding backend passes a leaf-only run and fails the recursive run with
SIGSEGV. This authorizes adoption and fresh cumulative validation, followed by
original-input production and an actual normal-resource self-rebuild.

The [normal-resource checkpoint](compiler_behavior_normal_resources_checkpoint_20261112.json)
records code `ba05fef4` after both 2,202-unit builds, eight readiness procedures,
all 17 integration gates, both 121-population native suites and all 1,092
required faults pass. Original compiler/runtime production remains complete,
with unchanged owners, balanced events and passing ELF audits. Both strict
native comparisons retain their nine changed-object failures; independent
reviews identify only smaller frames in four unique functions. Every preceding
command outcome and all optimizer/owner artifacts match. The frozen 3,441-file
source is retained verbatim.

The actual unchanged normal-resource self-rebuild now passes. Its frontend
uses the unchanged 46 MiB main stack, 60 MiB worker stack, affinity 0–15 and
16 threads. The self-build backend runs afresh, reproduces the original compiler
IR and emits the same complete compiler object. Separate freshly linked first-
and second-generation paths contain identical 150,460,616-byte executables,
SHA-256 `7dd08529a7e28532b6743917e73d335d6e393a345bfa6e600ffde2f241a23928`.
Both generations match all 2,097 reference outcomes in every normal LLVM mode
and pass all nine f80 checks. There is no controlled performance claim.

Final acceptance remains blocked. A new independent unsigned 256-bit remainder
probe receives a wrong middle limb from the local `__umodei4`; LLVM's object
from the same fixed runtime input returns the correct result. The original
accepted runtime object fails identically, and this function's bytes did not
change in the frame repairs. This is a preexisting uncovered arithmetic error,
not a passing validation result. Preserve the failed receipts, identify and
repair the shared cause, add unsigned normalization/limb regressions and run
immediate Tier 3 and fresh runtime production. Isolated behavior research and
both final complete local-hook matrices remain unaccepted.
