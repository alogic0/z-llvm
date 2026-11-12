# Complete compiler objects, runtime and self-rebuild

Date: 2026-11-11
Status: milestones 1–5 complete at `b738377e`, backend implementation `e398030f`;
follow-up milestones 6–8 authorized on 2026-11-11 and in progress. The normal-resource
self-rebuild and both normal-LLVM matrices pass at `ba05fef4`; the runtime
remainder error is repaired at `9cb21139`. The complete local-hook matrices and
final-source generations remain open. The original
five-milestone acceptance remains unchanged. See the
[completion evidence](../evidence/compiler_object_self_rebuild.md) and
[acceptance record](../evidence/compiler_object_self_rebuild_acceptance_20261111.json).
Baseline: accepted code `efa62fa2d182bf0a5f2c5e7b1b239dcbb0aab898`, documentation
`5490de0b909757afb57cacd27cc2f3ce5e176f10`.

## Objective and scope

Produce complete compiler and runtime objects, build the unchanged pinned Zig
compiler through the local postopt object hook, and prove startup, behavior and
self-rebuild. Keep each stage independently evidenced. The completed
[selection plan](2026-11-08-complete-compiler-selection.md) remains accepted;
selection alone does not establish these later stages.

Use x86_64 Linux GNU, CPU `baseline`, and the existing ReleaseFast, LLVM-enabled
whole-compiler configuration. LLVM continues to own frontend optimization and
the declared external provider libraries. z_llvm must own the compiler/runtime
objects delivered through the hook. Do not replace rejected bodies with stubs,
omit required globals, or substitute LLVM-generated objects for failed local
emission. This plan makes no claim that LLVM has been removed.

## Accepted baseline and fixed inputs

The [completion evidence](../evidence/compiler_selection_completion.md) and
[acceptance record](../evidence/compiler_selection_completion_acceptance_20261111.json)
establish:

| Population or stage | Accepted result |
| --- | --- |
| Original compiler module | 8,928/8,928 definitions selected; all prior identities and owners preserved |
| Compiler object | Blocked by `UnsupportedGlobalData` in `object_write`; output is empty |
| Original runtime module | 387/455 selected; 68 rejections remain |
| Compiler startup and self-rebuild | Unproven |
| Existing validation | All 17 integration gates and both 112-population native suites pass; all 594 new fault controls detected |

Keep these exact inputs and denominators:

- Compiler: 443,624,107 bytes, 8,928 definitions, SHA-256
  `de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`;
  `local-state/validations/compiler-selection-completion-20261108/batch-06/compiler-production/backend/input.ll`.
- Runtime: 1,856,543 bytes, 455 definitions, SHA-256
  `ca04995e5bc4d6537f6e1b994a79569ed8dc10d64451f89dfc0714fb40a732af`;
  `local-state/validations/whole-compiler-20261107/attempt-4/captures/3276317/input.ll`.
- Upstream Zig source pin:
  `1c08b09d1c847f4f02c8216e3b62df323861a437`; project tooling Zig 0.17.0.
  Record the actual emitter, backend, LLVM/provider libraries and CMake config
  paths and hashes for every accepted run.

Batch 30 is sealed historical evidence. Read its census, reports, profiles and
manifests; write successor work under fresh exclusive directories, for example
`local-state/validations/compiler-object-completion-20261111/`.
Fresh captures from an unchanged build must retain their own hashes and
definition inventories. Do not silently substitute them for the fixed inputs.

## Milestone 1: diagnose and close compiler object emission

### Identify the actual global-data boundary

1. Add bounded rejection context around the failing global-data/ELF operations
   in [global_data.zig](../../src/mc/global_data.zig) and
   [elf.zig](../../src/mc/elf.zig). Retain the original error name and report the
   symbol, type, initializer form, layout/flags and exact rejection reason.
   Include alias/reference context, section totals and applicable limits when
   those cause rejection. Keep diagnostics on stderr, separate from object
   stdout, and avoid dumping enormous initializers.
2. Build a focused Zig diagnostic using the existing parser, module context,
   global decoder and validation helpers. Load the unchanged input with its
   named types, aliases, functions, declarations and target layout. Inventory
   rejected forms and retain a minimal reproducer with the required context.
   An all-globals decoder scan is diagnostic evidence; it does not establish
   the actual required-symbol closure or complete object emission. Exercise
   the shared ELF closure/placement logic separately when the decoder passes.
3. Do not depend on a retained compiler ownership manifest: the current failed
   object run did not produce one. Reuse available metadata or add a supported
   diagnostic path with explicit provenance. Avoid repeating the roughly
   eighty-minute compiler replay merely to identify another initializer.

The initial inventory found 258 compiler decoder rejections: 31 string escapes,
200 poison scalar cells, 19 floating scalar layouts and eight relative-address
table expressions. The runtime has 11 floating-table decoder rejections. The
first compiler rejection is `__anon_4971`, whose 13-byte string contains LLVM's
double-backslash escape. This inventory is diagnostic evidence, not object or
required-closure credit. Subsequent candidate boundaries include unsupported
scalar/aggregate initializers, aliases or relocations, zero-sized placement,
the decoder's 1 MiB object bound, the 4,096-entry closure bound, and the 16 MiB
section bound. Distinguish an unsupported representation from a capacity or
accounting error before choosing a repair.

### Implement the observed forms

Extend the shared decoder, layout, symbol/relocation and ELF paths required by
the reproducer. Reclassify subsequent failures until the complete required
global set emits. Preserve target endianness, exact bits, alignment, aggregate
padding/offsets, linkage, visibility, aliases, pointer addends, function/block
addresses and TLS semantics where applicable. Unsupported forms remain closed.

Do not solve a capacity failure by deleting its guard. Establish the required
size/count, checked arithmetic, allocation/headroom budget and boundary tests
before changing a limit. The global-data bounds are separate from stack-object
authority. Preserve the frozen Source/value-use interfaces and inventories;
use existing typed transfer, storage and ABI contracts for any lowering work.

For each new form, retain a small LLVM IR fixture, object inspection and a
linked C/Zig execution oracle. Compare initializer bytes, sizes/alignment,
symbol properties and relocation targets/addends with LLVM's output; compare
semantics rather than requiring identical whole-object instruction bytes.
Exercise neighboring globals, exact stores/loads, negative cases and relevant
edge representations. Cover only forms actually admitted by the implementation.

Review existing rejection controls. In particular, `unsupported-global` in
[native_canaries.zig](../../tools/validation/native_canaries.zig) currently uses
`@value = global double 1.0`. If that form becomes supported, preserve its new
positive proof and replace the rejection fixture with a genuinely unsupported
or malformed case. Record the exact intentional contract change; do not weaken
negative checks or claim the old outcome stayed identical.

### Accept a complete captured compiler object

Freeze source and fresh compiler binaries, then replay the original compiler
input through [run_whole_compiler.zig](../../tools/run_whole_compiler.zig) with
`--input-ir` and `--profile-events`. Use the retained command shape, input-sized
limit, explicit backend and recorded deadline. Require all of the following:

- Complete census and independent production agree on all 8,928 identities,
  selections and preserved owners; events balance without interruption.
- Production returns actual zero, reports `failure_stage=none` and
  `object_complete=true`, and verifies unchanged source/backend/input identities.
- The object is nonempty, parses as an x86_64 ELF relocatable, and passes
  section, symbol, relocation, bounds and ownership checks. Missing required
  definitions/data and unexpected undefined symbols are failures; declared
  runtime/external providers remain explicit.
- The required validation tier, existing native preservation and new global
  execution/fault controls pass against this same source and toolchain.

This milestone proves the captured compiler module's object. It does not prove
that the unchanged compiler build links, starts or rebuilds itself.

## Milestone 2: complete runtime selection and object emission

Start from the complete batch-30 runtime census. Its 68 rejections group as
60 `UnsupportedCodegenControlFlow`, six `UnsupportedCodegenInstruction`, one
`UnsupportedCodegenType` and one `UnsupportedLongDoubleAbi`. These diagnostic
names are an initial inventory, not four established root causes.

1. Classify each original rejection by instruction, operands, types, physical
   locations and ABI requirements. Implement cohesive families through shared
   lowering, transfer and storage contracts. Replay affected original functions
   after each repair and reclassify later boundaries.
2. Add independent LLVM/native tests for the defined behavior of each family,
   including live values, ABI edges, exact memory accesses and injected faults.
   Check that compiler-rt implementations do not lower into recursive calls to
   themselves through exported aliases or helper names. External dependencies
   must match the real build's declared provider contract.
3. Preserve all 387 accepted runtime selections and owners and all 8,928 compiler
   selections and owners. Focused gains stay provisional until complete census,
   independent production and event audits cover the unchanged inputs.
4. Require **455/455 runtime selections**, zero rejections and a complete,
   nonempty validated runtime object. Apply the same globals/relocations and
   ownership checks as the compiler-object milestone. Selection alone cannot
   close runtime object emission.

Preserve the original 455-definition corpus even if a later build emits a
different runtime module. Retain and account for that new module separately.

## Milestone 3: build and link the unchanged compiler

Use the existing [whole-compiler runner](../../tools/run_whole_compiler.zig)
without `--input-ir` once the captured compiler and runtime object prerequisites
pass. Keep the original upstream source pin and tracked source clean. Retain
the original and resolved CMake configs, emitter/backend receipts, provider
library hashes, build flags, target, CPU, environment and cache provenance.

Use its existing LLVM-enabled ReleaseFast configuration and capture proxy.
Dedicated build caches must not conceal objects produced by another backend.
Require:

- An actual compiler-module hook capture, all runtime/other hook invocations
  accounted for, and local `object_complete=true` for every delivered object.
- The postopt hook marker and backend/input identities for every invocation;
  complete definitions, globals and provider/relocation accounting.
- Actual zero for the build/link and a newly produced candidate executable
  whose hash and ELF/link dependencies are retained.
- No fallback object, omitted required symbol, empty/partial object or stale
  executable accepted as success. A runtime-only capture cannot prove that the
  compiler module was built locally.

An unresolved link is a link milestone failure even when both fixed captured
objects pass. Diagnose its symbols, provider ownership and ABI with the narrowest
reproducer; retain preceding successful milestones against their exact inputs.

The current runner proceeds automatically from linking to startup, behavior and
self-rebuild. Treat its stage fields as separate results. Do not assume it has
stop/resume flags. Add explicit staged execution only if needed, with supported
CLI options, source/binary binding and tested resumption contracts.

## Milestone 4: prove startup and compiler behavior

Run the newly produced candidate itself and retain actual commands, outputs,
exit status and executable hash. Require its version to match the pinned
frontend and run the existing unchanged `hello_libc` and `while_loops` cases
against their manifest source hashes and expected observations. Preserve the
invalid-source compile-error control and its expected diagnostic.

Record the compilation pipeline used by these behavior checks. The current
runner uses the candidate's normal `-fllvm` path for these programs; that proves
candidate functionality, not additional local object-backend coverage. Any
extra local-hook behavior cases need their own capture/ownership proof and
independent reference results.

A successful version command closes startup only. Behavior requires successful
compilation and execution of the programs plus correct invalid-source rejection.

## Milestone 5: prove self-rebuild

Use the newly built candidate as the frontend to rebuild the same pinned
compiler source with the same configuration, providers and local postopt object
hook. The existing runner already supplies this path; retain a separate capture
root, cache/install roots, hook marker and complete reports for the rebuild.

Require an actual compiler-module capture in the second build, complete local
objects for every hook invocation, successful link, and a distinct retained
rebuilt executable. Runtime-only captures or a reused first-stage executable
cannot establish self-rebuild. Run version, the unchanged behavior programs and
the invalid-source control with the rebuilt candidate as well.

Record both executable identities and their producing toolchains. Bit-for-bit
executable equality is not required unless reproducible-build behavior is
separately established. This milestone proves rebuilding through the specified
local object hook while retaining LLVM optimization and declared providers.

## Validation and acceptance

Follow [validation tiers](../validation_tiers.md) and
[the working cycle](../working-cycle.md). Use focused diagnostics and executable
reproducers during development. ELF/relocation, shared ABI/frame, verifier and
confirmed wrong-code changes retain their immediate Tier-3 requirements. Record
the trigger, exact command, evidence root and reuse decision before each full
run. Gate/cache changes require the existing fresh/cache comparison as well.

At each accepted capability checkpoint:

- Run the required focused tests, LLVM/object inspection, executable oracles,
  negative/injected-failure controls and relevant captured real rows.
- Run Debug and ReleaseSafe units, structural and profile checks, readiness,
  and the full serial 17-gate distribution suite when required by the routing.
  Keep explicit compiler, emitter, source and cache selections and verify their
  propagation into child commands.
- Preserve all 112 baseline native entries, the 4,133 baseline command outcomes
  and the retained artifact inventory in both compiler build modes. Add new
  populations for new capabilities. Compare all unaffected artifacts and
  outcomes strictly. Record any necessary changed control or corrected object
  individually with its cause, before/after facts and independent semantic/ABI
  proof; no blanket waiver or silently rewritten baseline is acceptable.
- Preserve the fixed real prefix 100, execution cohort 12, all 36 core
  selected-object/observation records, ratchet 130 and accepted-status file.
  Review wrapper metadata separately from selected code and observations.
- Complete original-input census, independent production and event/owner
  audits for the compiler and runtime at the relevant cumulative checkpoints.
  Require 8,928/8,928 compiler selection throughout and 455/455 runtime selection
  for runtime completion. Intermediate runtime gains remain explicitly partial.
- Freeze source/build inputs before long runs. Bind the executed binaries,
  reports and input identities to the committed tree after completion. Reuse a
  gate only when its relevant source, toolchain, target, mode, corpus, arguments
  and expected-result contract match. Later source changes need a new reuse
  decision and the corresponding fresh checks.

Do not require identical whole-distribution logs after adding populations or
changing a reviewed contract. Retain strict comparator results and explain
every difference while separately proving all unaffected objects, observations,
controls and cohort identities. Timing collected under concurrent load does
not establish a controlled performance improvement.

## Runner use and evidence

Extend the existing Zig runners and [validation helpers](../../tools/validation/common.zig)
only where the required observation is missing. Keep maintained generators,
failure checks, comparisons and diagnostic tooling in Zig; do not reintroduce
Python helpers or inline Python. Avoid a second whole-compiler orchestrator.

For a frozen candidate, the captured-object replay uses the existing command
shape below. Choose a fresh batch root and build the backend there first:

```sh
completion_root=local-state/validations/compiler-object-completion-20261111/batch-01
completion_backend="$PWD/$completion_root/compiler/ReleaseFast/bin/z_llvm"
zig run tools/build_validation_compiler.zig -- \
  --output-root "$completion_root/compiler" --mode ReleaseFast
zig run tools/run_whole_compiler.zig -- \
  --output-root "$completion_root/compiler-object" \
  --zllvm "$completion_backend" \
  --input-ir local-state/validations/compiler-selection-completion-20261108/batch-06/compiler-production/backend/input.ll \
  --timeout-ms 7200000 --profile-events
```

Replay the fixed runtime input into its own exclusive output root. The later
unchanged build uses the same runner without `--input-ir`, with explicit
`--zig-source`, `--zig-emitter` and `--config-h`. Its single attempt may produce
separate build, startup, behavior and self-rebuild results. Record actual command
deadlines from measured needs; a timeout extension does not constitute progress.

Retain source snapshots, build receipts, complete command outcomes, original
and effective arguments, original/effective configs, input hashes, profiles,
balanced event audits, ownership and ELF contracts, objects, executables,
observations and failure controls. Track each hook invocation and both rebuild
generations independently. Distinguish parse/verify/selection/object/link/
startup/behavior/rebuild failures from cancellation, timeout and resource stops.
Keep bounded global diagnostics and minimal reproducers alongside their exact
original-module context. Publish milestone-specific acceptance records and
update active documentation only after their required proofs pass.

## Resources and retention

Follow the current [headroom and retention policy](../retention_headroom_policy.md),
not the superseded thresholds in the historical whole-compiler diagnostic plan.
Serial and whole-compiler admission requires 20,000,000,000 free bytes; enforce
the 11,410,065,408-byte execution reserve and inherited stronger caller floors.
Record disk sampling, wall time, peak RSS, signals and actual process outcomes.

Preserve sealed batch-30 and preceding evidence, both original inputs, accepted
compiler binaries, authenticated AIR payloads, shared object bundles and all
thirteen scratch files. Use runner-owned cleanup within its documented scope.
Create no archives or manual cleanup as part of this plan. Use streaming event
audits and bounded diagnostic output for the large module. Revisit performance
only when an observed required replay cannot finish, and retain its blocker.

## Follow-up milestone 6: upstream behavior suite

Run the unchanged pinned upstream `test/behavior.zig` suite with both retained
compiler generations and the pinned reference on x86_64 Linux GNU, CPU
`baseline`, in Debug, ReleaseSafe, ReleaseFast and ReleaseSmall. Use upstream's
test imports and runner; retain every test identity, pass, skip and failure.
Record the exact libc/threading configuration and mirror it across routes.
Do not silently filter failures or substitute a small sample for the full suite.

First establish the reference and each candidate's normal `-fllvm` behavior.
Then repeat candidate compilation with the local postopt object hook explicitly
enabled. Every hook invocation must retain input/backend identities, actual
process outcome, complete-object/owner/ELF checks and delivery provenance. Require
at least the behavior module capture; a cache hit or runtime-only capture earns
no behavior-module backend credit. Use separate caches and evidence roots for
each generation, mode and route. Compare named test outcomes with the reference,
including upstream's legitimate target-specific skips. A successful compiler
invocation without execution does not establish behavior.

## Follow-up milestone 7: close behavior failures

Classify each failure as frontend, local selection, object/link, execution,
test-harness or resource failure. Preserve the original failing invocation and
derive the smallest reproducer. Repair cohesive families through existing shared
contracts, with independent LLVM/native regressions and negative controls; never
add case-name exceptions, fallback objects or blanket expected-failure waivers.
Confirmed wrong-code and shared ABI/frame changes require immediate Tier 3.
Rerun affected cases before repeating the complete matrix. Acceptance requires
both generations to match the reference's complete named outcomes in all four
modes through the local hook, with no unaccounted failures or missing captures.

The first accepted repair is the [floating PHI checkpoint](../evidence/compiler_behavior_progress.md)
at `84f1ad7c`. All four reference modes pass. Both retained generations fail
`@exp with vectors` in all four normal-LLVM modes; the reduced runtime case
exposes a literal overwriting a named floating PHI snapshot. The shared planning
repair passes all 17 integration gates, both 116-population native suites,
2,183 units plus 63 structural/two profile checks per unit build and all 822
fault controls. This accepts the repair, not rebuilt compiler generations or
the complete follow-up matrix.

Continue with the observed local-hook boundaries: quoted global names and
vector splats, wide integer forms, x87 vectors, floating atomics, varargs and
the ReleaseSmall runtime's ABI/instruction forms. Retain exact failing inputs
and extend shared parser/lowering/object contracts with independent execution
and rejection controls. Do not normalize the accepted suite or filter cases.

The [vector checkpoint](../evidence/compiler_behavior_vector_checkpoint_20261111.json)
accepts code `a328d225` for quoted global references, floating vector data and
packed x87 lanes. Both 117-population native suites, all 17 integration gates,
2,188 units plus 64 structural/two profile checks per unit build and all 876
fault controls pass. The unchanged Debug hook attempt reaches variadic parsing;
its runtime object is complete, and its behavior object remains unproven. Keep
the remaining wide-integer, variadic, floating atomic and Small-mode boundaries
open. Registry ordering was corrected after the frozen run, with identical
population contracts and fresh strict preservation comparisons.

## Follow-up milestone 8: normal-resource self-rebuild

Measure the final accepted compiler under inherited normal stack limits and
normal CPU affinity before assuming that earlier resource failures still apply.
Retain actual limits, affinity, largest frames/call chains, signals and outcomes.
Use narrow frontend probes to diagnose excessive spill/frame growth. Repair the
shared cause with regression coverage rather than raising the 8 MiB generated
frame or 64 KiB stack-object guards, changing pinned upstream sources or hiding
failures with single-CPU execution.

Require a fresh unchanged-source self-rebuild with normal worker scheduling,
without `--self-cpu` or a raised OS stack limit, complete compiler/runtime hook
captures and a distinct rebuilt executable. Run version, the original behavior
controls, the f80 regression and the full four-mode upstream behavior suite with
that executable. Keep the CPU-0 / 1 GiB result as the historical accepted baseline
until this stronger result passes. LLVM optimization and declared providers
remain in scope; performance tuning and further LLVM removal are later work.

The retained normal-resource frontend probe fails with SIGSEGV under the
inherited 46 MiB main-stack limit and CPU affinity 0–15. Parent-launched debugger
evidence identifies `Sema.analyzeBodyInner`'s stack-probing prologue touching below
the main-stack mapping. Isolated spill-home
coloring research reduces the large Sema frame but fails existing tests; it
must not be adopted on selection or frame-size measurements alone.

Unused spill-reserve compaction is a separate tested candidate. It retains every
spill home and interval, removes only an unreferenced gap, rebases owned-object
and incoming-stack offsets, preserves temporary stack bias, alignment and page
touching, and retains opaque cases unchanged. Its isolated proof passes all
2,188 units, executable/negative stack controls, all 117 native populations and
432 fault controls. The reviewed code is adopted for immediate Tier 3 and fresh
source-bound compiler/runtime replays, then require the actual normal-resource
build and self-rebuild before closing this milestone.

Write successor evidence under
`local-state/validations/compiler-behavior-completion-20261111/`, preserving the
prior artifact seal and publication at `6253b063`. Mutable documentation leaves
in the old manifest are authenticated against that committed publication and
retained verbatim snapshots; do not rewrite historical manifests or acceptance.

Follow-up completion requires cumulative validation appropriate to changed
subsystems, exact source/binary/provider binding, updated documentation and a
new evidence seal. Reuse unchanged gates only under the existing reuse policy.

- [x] Run the complete four-mode reference matrix.
- [x] Build the first repaired generation and match all four normal-LLVM reference outcomes.
- [ ] Produce the final second generation and complete both final candidate matrices.
- [ ] Prove complete local-hook captures and matching named test outcomes.
- [ ] Repair observed failures with focused regressions and required cumulative validation.
- [x] Diagnose and remove special CPU-affinity and main-stack requirements at `ba05fef4`.
- [x] Prove normal-resource self-rebuild and both normal-LLVM four-mode matrices at `ba05fef4`.
- [ ] Repair the independently reproduced unsigned multiword remainder error and repeat affected production proofs.
- [ ] Publish follow-up acceptance and seal successor evidence.

The completed PHI, vector and
[frame checkpoints](../evidence/compiler_behavior_frame_checkpoint_20261111.json)
remain accepted independently. Trailing-gap compaction passes its frozen Tier-3
validation, fresh complete original compiler/runtime replays and the 64 KiB
worker-stack regression. The newly built first generation matches all 2,097
reference outcomes in all four normal LLVM modes and passes f80 layout checks.
Normal-resource self-rebuild still fails with frontend SIGSEGV in Sema's
stack-probing prologue. Keep this failed run and diagnose the remaining frame
growth; interior spill-reserve compaction and explicit stack-object lifetime
reuse require independent proofs before adoption. The complete local-hook
behavior matrix and final second generation remain open.

The active resource slice now adopts whole-object lifetime reuse and interior
unused spill-chunk removal for immediate Tier 3. Explicit lifetime starts and
ends bound the object interference analysis across branches and loops; source
IR, distinct referenced spill homes and ABI remain unchanged. Four new analysis
controls, all 2,194 isolated units and the two-function `stack_lifetimes` native
population pass, including all three modes and 27 injected faults. The old
backend fails its 64 KiB worker-stack regression with actual SIGSEGV. The measured
Sema frame falls to 479,000 bytes. Complete fresh cumulative validation and
source-bound compiler/runtime replays before the next actual unchanged build
and normal-resource self-rebuild. Neither this measurement nor the isolated
regression closes milestone 8.

The [lifetime checkpoint](../evidence/compiler_behavior_lifetimes_checkpoint_20261112.json)
now accepts code `8b38e8cd`: both unit builds, all eight readiness procedures,
all 17 integration gates, both 119-population native suites and all 984 required
fault controls pass. All 4,349 prior native command outcomes and their objects,
owners and optimizer artifacts match exactly. Fresh original compiler/runtime
objects are complete, with unchanged owners, balanced events and passing ELF
audits. The new first generation matches all 2,097 reference outcomes in each
normal LLVM mode and passes all nine f80 observations.

The fresh normal-resource self-rebuild still fails with frontend SIGSEGV.
Parent-launched debugger evidence now places the fault in the stack-probing
prologue of `InternPool.Key.hash64`; the cumulative active stack still exceeds
the inherited 46 MiB limit. Keep this failed result and both compiler generations
separate. A checked reconstruction contains 207 owned frames with all 206 call
edges matching the executable; 95 Sema frames account for 45,505,000 bytes.
Next, prove any further frame repair through final machine memory accesses and
CFG liveness. Preserve overlapping access groups, partial
writes, alignment, live objects, call arguments and every opaque escape; do not
revive the failing SSA-interval prototype. Run the required cumulative validation
and original-input replays before another actual normal-resource self-rebuild.

Behavior research remains provisional: exact Valgrind client requests,
byte/halfword XMM arguments, extended return payloads and constant comparisons
raise the unchanged Debug behavior input to 7,196/7,874 selections. Independent
native proofs do not establish its complete object or either final local-hook
matrix. Continue bounded wide-integer and remaining instruction/ABI families;
preserve the original input, named outcomes and rejection controls at adoption.

The next resource slice adopts final machine spill-home reuse for immediate
Tier 3. Exact loads and stores define indivisible overlapping access groups;
CFG memory liveness bounds their closed intervals, including partial writes,
backedges and dead stores. An independent cell-placement check rejects live
overlap. Preserve alignment phase, incoming/outgoing stack bias and opaque
escapes. Batched analysis retains the 64 MiB table limit; the Sema proof uses
8,115,712 bytes and reduces its measured frame from 479,000 to 53,144 bytes.
Choose this placement only when it saves another page beyond existing gap-only
compaction; keep that compactor's smaller result otherwise.

Six focused controls and all 2,201 isolated units pass. The new
`stack_spill_homes` population keeps 16 values live across 512 ten-argument C
calls on a 64 KiB pthread stack. Both backend builds pass all three modes,
45,096 observations per execution and 27 injected faults each; the preceding
backend fails with actual SIGSEGV while LLVM passes. A maintained Zig generator
reproduces the 880,016-byte fixture exactly. Complete fresh cumulative validation,
original compiler/runtime replays and the actual unchanged normal-resource
self-rebuild before accepting this repair or closing milestone 8.

## Delivery checklist

The [machine-home checkpoint](../evidence/compiler_behavior_machine_homes_checkpoint_20261112.json)
now accepts code `ee87c488` after both 2,200-unit builds, all eight readiness
procedures, all 17 integration gates, both 120-population native suites and
all 1,038 required fault controls pass. Strict native comparisons retain all
4,385 prior outcomes and remain failed for 18 reviewed objects per build;
each difference contains only the documented frame reductions. Fresh original
compiler/runtime objects are complete, with unchanged owners and passing event
and ELF audits. The frozen 3,436-file source is retained verbatim.

The new first generation matches all 2,097 reference outcomes in each normal
LLVM mode and passes all nine f80 checks. Normal-resource self-rebuild still
fails, now in a worker's `InternPool.zigTypeTag` probing prologue. The unchanged
upstream worker stack is 60 MiB; CPU affinity remains 0–15 and the inherited
main-stack limit remains 46 MiB. A checked reconstruction contains 1,213 owned
frames, 1,210 verified direct call edges and two recorded indirect edges.
Repeated `genBodyDebugScope` and `genBody` frames account for 59,288,024 bytes;
241 `lowerBlock` frames add 3,129,144 bytes. A frontend-only probe succeeds but
changes emission demand, so it cannot close the full rebuild.

Continue with this measured worker-stack boundary. First determine whether
existing unused-gap compaction can safely cover the medium frames below its
64 KiB activation threshold. That threshold is a profitability heuristic,
separate from the unchanged 64 KiB stack-object and 8 MiB frame guards. Preserve
the existing access/rebasing proof, minimum worthwhile savings, owned objects,
alignment and outgoing arguments. Add a recursive worker-stack regression,
complete the required cumulative validation and original-input replays, then
repeat the actual normal-resource self-rebuild. Do not infer success from
smaller frames alone. Both final generations and the complete local-hook matrix
remain open.

Separately preserved behavior research now selects 7,415/7,874 original Debug
definitions. Bounded limb arithmetic and expanded switch widths have independent
execution proofs; additional wide intrinsics remain provisional. LLVM 22 rejects
the new full-width dynamic-funnel reference fixture before candidate execution.
Keep that failure and distinguish available JIT/oracle proofs from complete
native population acceptance. None of these isolated research sources is adopted
by the machine-home checkpoint.

The isolated worker-stack repair now passes all 2,202 units and both backend
builds of a new recursive native regression. Existing gap compaction reduces
`genBodyDebugScope` from 63,528 to 24,456 bytes by removing 39,072 unreferenced
bytes. Consider frames from 32 KiB and require at least 8 KiB of unused-gap
savings; the memory-home policy and stack-object/frame guards remain intact.
Two new controls exercise medium-frame rebasing, incoming words, outgoing bias
and closed opaque cases. The native population keeps 16 values live around
48 ten-argument calls and four recursive activations on a fixed 128 KiB stack.
Its frame falls from 44,744 to 7,400 bytes. LLVM and both candidate builds pass
all three modes and 27 faults each; the preceding backend passes its leaf case
and fails the recursive case with actual SIGSEGV. A maintained Zig generator
reproduces the 74,928-byte fixture exactly.

Adopt this bounded profitability change for immediate Tier 3. Preserve the
120-population prefix, run fresh complete compiler/runtime production against
the original inputs, and repeat the actual unchanged normal-resource build and
self-rebuild. Smaller measured frames and the isolated regression do not close
milestone 8.

### Current checkpoint and remaining implementation order

The [normal-resource checkpoint](../evidence/compiler_behavior_normal_resources_checkpoint_20261112.json)
records the completed `ba05fef4` run. Both unit builds pass 2,202 units,
64 structural and two profile checks; all eight readiness procedures, all
17 integration gates, both 121-population native suites and all 1,092 required
fault controls pass. Fresh original compiler/runtime production retains all
8,928/455 definitions and owners, with balanced events and passing ELF audits.
The frozen 3,441-file source is retained verbatim.

The unchanged normal-resource build and self-rebuild return actual zero. The
self-build executes the backend afresh and emits the original compiler IR and
the same compiler object. Separate freshly linked generation paths contain the
same 150,460,616-byte executable, SHA-256
`7dd08529a7e28532b6743917e73d335d6e393a345bfa6e600ffde2f241a23928`.
Each generation matches all 2,097 reference outcomes in each normal-LLVM mode
and passes all nine f80 observations. Measured frontend resources are the
unchanged 46 MiB main stack, 60 MiB worker stack and CPU affinity 0–15, with
16 threads. The pinned executable raises its shell-inherited 8 MiB main-stack
limit to its existing ELF stack request; this run adds no stack override.

These resource results do not close the follow-up acceptance. A new independent
C test exposes wrong unsigned multiword remainder output in the local runtime;
the same original IR compiled by LLVM passes. The original accepted runtime
object also fails this test, establishing a preexisting uncovered error. Retain
the failed receipts and implement the following steps in order:

1. **Complete at `9cb21139`.** Reduce the remainder failure to the actual shared lowering or machine-code
   cause. Add independent unsigned division/remainder coverage across limb
   boundaries, normalization shifts and numerator/denominator orderings. Keep
   the original failing operands and LLVM reference proof.
2. **Complete at `9cb21139`.** Repair that shared cause without helper-name exceptions, source changes,
   fallback objects or relaxed guards. Run the focused controls and immediate
   Tier 3, then repeat original runtime production, owner/event/ELF checks and
   the independent arithmetic oracle against the new object.
3. Finish and review the isolated behavior-family changes against the accepted
   source. Preserve the cumulative lifetime, machine-memory and medium-frame
   repairs. Admit each family only after both native builds, fault controls,
   full original-input replay and exact preservation checks pass. Failed
   prototype/reference runs remain diagnostic evidence.
4. Build the final source-bound compiler generations, audit every local-hook
   capture, and match the complete named reference outcomes in all four modes
   for both generations. The completed normal-LLVM matrices cannot substitute
   for these local-hook matrices.
5. Repeat the normal-resource rebuild and affected final-generation checks when
   their relevant code changes, bind all final artifacts to the committed source,
   and publish the successor acceptance and seal. Keep the prior five-milestone
   seal and all failed resource/arithmetic attempts unchanged.

The [scalar-liveness checkpoint](../evidence/compiler_behavior_scalar_liveness_checkpoint_20261112.json)
closes steps 1–2. Named shifts and boolean operations destroyed live accumulator
sources before later uses and PHI edges; both now use the existing liveness-aware
preservation contract. The independent runtime oracle covers 641 cases across
five widths and all four unsigned helpers. Both complete 455-definition runtime
objects pass 21,792 observations per route and 14 faults per build. All 17 gates,
both 122-population native suites, strict prior-artifact comparisons and all
1,162 required faults pass. The original 8,928-definition compiler object and
owners are byte-identical to the preceding checkpoint; events and ELF pass.

Both corrected unit suites pass 2,204 units, 64 structural and two profile checks.
The sole post-production source change corrects an old unit that expected the
wrong destructive stream while marking its source live. Its separate source
bridge preserves every defined function, object and TLS storage byte in both
fresh builds; Debug padding/debug-file differences remain recorded. This bridge
does not relax the automatic compiler-object reuse guard. Retain the failed old
unit receipts. Final generations and the complete local-hook matrix still need
fresh evidence after the behavior-family changes.

- [x] Identify the exact first global rejection and retain a focused reproducer.
- [x] Implement the required shared global/ELF forms with LLVM/native and negative proofs.
- [x] Emit and validate the complete original compiler object, retaining all 8,928 selections.
- [x] Complete all 455 original runtime selections and validate its complete object.
- [x] Build and link the unchanged pinned compiler with complete local hook provenance.
- [x] Prove first-generation startup, behavior and invalid-source rejection.
- [x] Rebuild with that candidate; prove second-generation captures, link, startup and behavior.
- [x] Complete cumulative validation, source/binary/provider binding, documentation and evidence seals.

Acceptance retains the original inputs and separate fresh captures, explicit
verified first-generation compiler-object reuse, fresh self-build backend
executions and two distinct executable identities. The self-build frontend uses
CPU 0 and a 1 GiB main stack; the 8 MiB generated-frame, 64 KiB stack-object and
60 MiB upstream worker-stack limits remain unchanged. Both generations pass the
f80 layout regression. LLVM optimization and declared providers remain in scope.
