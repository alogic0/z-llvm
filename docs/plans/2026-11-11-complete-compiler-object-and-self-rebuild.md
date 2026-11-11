# Complete compiler objects, runtime and self-rebuild

Date: 2026-11-11
Status: in progress; compiler object emitted and independently audited; runtime
selection repair and cumulative acceptance are in progress.
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

## Delivery checklist

- [x] Identify the exact first global rejection and retain a focused reproducer.
- [x] Implement the required shared global/ELF forms with LLVM/native and negative proofs.
- [ ] Emit and validate the complete original compiler object, retaining all 8,928 selections.
- [ ] Complete all 455 original runtime selections and validate its complete object.
- [ ] Build and link the unchanged pinned compiler with complete local hook provenance.
- [ ] Prove first-generation startup, behavior and invalid-source rejection.
- [ ] Rebuild with that candidate; prove second-generation captures, link, startup and behavior.
- [ ] Complete cumulative validation, source/binary/provider binding, documentation and evidence seals.

The immediate first deliverable is a named global-data rejection with its
specific reason, required context and minimal fixture, followed by the smallest
shared repair justified by that evidence.
