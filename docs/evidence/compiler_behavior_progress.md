# Upstream behavior and resource follow-up

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
